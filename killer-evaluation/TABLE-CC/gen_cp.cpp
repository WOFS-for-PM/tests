#include <fstream>
#include <iostream>
#include <string.h>
#include <vector>
#include <cassert>
#include <algorithm>
#include <random>
#include <argparse/argparse.hpp>

typedef unsigned long long u64;
typedef long long s64;

enum hk_trace_action
{
    HK_TRACE_CKPT,
    HK_TRACE_IO,
    HK_TRACE_FENCE,
};

enum hk_cmd_type
{
    HK_CMD_CKPT,
    HK_CMD_SFENCE,
    HK_CMD_CLWB,
    HK_CMD_MOVNTI,
};

inline const char *ToString(hk_cmd_type cmd)
{
    switch (cmd)
    {
    case HK_CMD_CKPT:
        return "HK_CMD_CKPT";
    case HK_CMD_SFENCE:
        return "HK_CMD_SFENCE";
    case HK_CMD_CLWB:
        return "HK_CMD_CLWB";
    case HK_CMD_MOVNTI:
        return "HK_CMD_MOVNTI";
    default:
        return "Unknown";
    }
}

#define HK_TRACE_MAX_KEYWORD_LEN 64

struct hk_trace
{
    char keyword[HK_TRACE_MAX_KEYWORD_LEN];
    char action;
    u64 addr;
    u64 size;
} __attribute__((packed));

struct hk_cmd
{
    char type;
    u64 addr;
    u64 size;
    loff_t f_pos; // point to real data
};

static enum hk_cmd_type cast_type_from_action(enum hk_trace_action action)
{
    switch (action)
    {
    case HK_TRACE_CKPT:
        return HK_CMD_CKPT;
    case HK_TRACE_FENCE:
        return HK_CMD_SFENCE;
    default:
        return HK_CMD_CLWB;
    }
    return HK_CMD_CKPT;
}

static enum hk_cmd_type cast_type_from_keyword(const char *keyword)
{
    if (strcmp(keyword, "memcpy_to_pmem_nocache") == 0 || strcmp(keyword, "memset_nt") == 0)
        return HK_CMD_MOVNTI;
    else
        return HK_CMD_CLWB;
}

static int gen_cmd_from_trace(struct hk_trace *trace, std::vector<hk_cmd> &cmds, loff_t f_pos)
{
    switch (trace->action)
    {
    case HK_TRACE_CKPT:
    case HK_TRACE_FENCE:
    {
        struct hk_cmd *cmd = new hk_cmd;
        cmd->type = cast_type_from_action(static_cast<enum hk_trace_action>(trace->action));
        cmd->addr = trace->addr;
        cmd->size = trace->size;
        cmd->f_pos = 0;
        cmds.push_back(*cmd);
        break;
    }
    case HK_TRACE_IO:
    {
        enum hk_cmd_type type = cast_type_from_keyword(trace->keyword);
        int default_stride = type == HK_CMD_MOVNTI ? 8 : 64;
        u64 addr = trace->addr;
        s64 size = trace->size;

        while (size > 0)
        {
            struct hk_cmd *cmd = new hk_cmd;

            cmd->type = type;
            cmd->addr = addr;
            cmd->size = size > default_stride ? default_stride : size;
            cmd->f_pos = f_pos;
            cmds.push_back(*cmd);

            addr += default_stride;
            size -= default_stride;
            f_pos += default_stride;
        }

        break;
    }
    default:
        return -1;
    }

    return 0;
}

u64 gen_one_crash_seq(std::vector<hk_cmd> cmds, std::vector<hk_cmd> &reordered_cmds, int seed)
{
    // the first fence is at the beginning
    s64 last_fence = 0;
    // copy cmds to reordered_cmds
    reordered_cmds = cmds;

    // set random seed
    std::srand(seed);

    // Step 1: find fences, reordering I/Os between them using shuffling
    for (unsigned long i = 0; i < reordered_cmds.size(); i++)
    {
        if (reordered_cmds[i].type == HK_CMD_SFENCE)
        {
            // shuffle I/Os between last_fence and i
            std::shuffle(reordered_cmds.begin() + last_fence + 1,
                         reordered_cmds.begin() + i,
                         std::default_random_engine());
            last_fence = i;
        }
    }

    // Step 3: random crash point selection, must reside between [0, cmds.size())
    //         a crash happens right after the selected crash point
    //         e.g., cmd1, cmd2, ..., cmdN, crash_point, cmdN+1, cmdN+2, ...
    u64 crash_point = std::rand() % reordered_cmds.size();

    return crash_point;
}

int create_image(std::vector<hk_cmd> cmds, u64 end, std::ifstream &trace, std::ofstream &image)
{
    u64 i = 0;

    for (i = 0; i < end; i++)
    {
        hk_cmd cmd = cmds[i];
        if (cmd.type == HK_CMD_CLWB || cmd.type == HK_CMD_MOVNTI)
        {
            char *buf = new char[cmd.size];

            // read data
            trace.clear();
            trace.seekg(cmd.f_pos);
            trace.read(buf, cmd.size);

            // write data
            image.clear();
            image.seekp(cmd.addr);
            image.write(buf, cmd.size);
            // free buffer
            delete[] buf;
        }
    }

    // make sure the image is persistent
    image.flush();

    return 0;
}

static bool check_write_state_change(hk_cmd cmd, std::ifstream &trace_file)
{
    if (cmd.type == HK_CMD_MOVNTI || cmd.type == HK_CMD_CLWB)
    {
        char *buf = new char[cmd.size];

        trace_file.clear();
        trace_file.seekg(cmd.f_pos);
        trace_file.read(buf, cmd.size);

        for (u64 i = 0; i < cmd.size; i++)
        {
            if (buf[i] != 0)
            {
                delete[] buf;
                return true;
            }
        }

        delete[] buf;
        return false;
    } else {
        return false;
    }
}

void interpret_cmds(const char *title, std::vector<hk_cmd> cmds, std::ifstream &trace_file)
{
    u64 i = 0;
    std::cout << "[" << title << "]" << std::endl;
    std::cout << "#. CMD ADDR SIZE F_POS" << std::endl;

    for (auto cmd : cmds)
    {   
        std::cout << std::dec << "[" << i++ << "] ";
        std::cout << ToString(static_cast<enum hk_cmd_type>(cmd.type)) << ", ";
        std::cout << std::hex << "0x" << cmd.addr << ", ";
        std::cout << std::dec << cmd.size << ", ";
        std::cout << cmd.f_pos << std::endl;

        if (cmd.type == HK_CMD_MOVNTI || cmd.type == HK_CMD_CLWB)
        {
            char *buf = new char[cmd.size];

            trace_file.clear();
            trace_file.seekg(cmd.f_pos);
            trace_file.read(buf, cmd.size);

            // out put hex
            for (u64 i = 0; i < cmd.size; i++)
            {
                std::cout << std::hex << (int)buf[i] << " ";
            }
            std::cout << std::endl;

            // output ascii
            for (u64 i = 0; i < cmd.size; i++)
            {
                std::cout << buf[i];
            }
            std::cout << std::endl;

            delete[] buf;
        }
    }
}

int main(int argc, char *argv[])
{
    argparse::ArgumentParser program("gen_cp");

    program.add_argument("-t", "--trace")
        .required()
        .help("trace file");

    program.add_argument("-l", "--latest")
        .required()
        .help("latest image file");

    program.add_argument("-c", "--crash")
        .required()
        .help("crash image file");
    
    program.add_argument("-s", "--seed")
        .default_value(0)
        .help("random seed")
        .scan<'i', int>();

    try
    {
        program.parse_args(argc, argv);
    }
    catch (const std::exception &err)
    {
        std::cerr << err.what() << std::endl;
        std::cerr << program;
        return 1;
    }

    char *trace_file_path = program.get<std::string>("-t").data();
    char *latest_file_path = program.get<std::string>("-l").data();
    char *crash_file_path = program.get<std::string>("-c").data();
    int seed = program.get<int>("-s");

    std::ifstream trace_file(trace_file_path, std::ios::binary);
    std::ofstream latest_file(latest_file_path, std::ios::binary);
    std::ofstream crash_file(crash_file_path, std::ios::binary);

    std::vector<hk_cmd> cmds;

    if (!trace_file)
    {
        std::cerr << "Failed to open file." << std::endl;
        return 1;
    }

    // Step 1: parse trace
    hk_trace trace;
    memset(&trace, 0, sizeof(hk_trace));
    while (trace_file.read(reinterpret_cast<char *>(&trace), sizeof(hk_trace)))
    {
        // addr is within the range of pmem, i.e., (0, 0x3E03E00000) (266352984064 bytes)
        assert(trace.addr < 0x3E03E00000);

        gen_cmd_from_trace(&trace, cmds, trace_file.tellg());

        trace_file.seekg(trace.size, std::ios::cur);
        memset(&trace, 0, sizeof(hk_trace));
    }

    // interpret_cmds("Basic Trace", cmds, trace_file);

    std::vector<hk_cmd> reordered_cmds;
    u64 crash_point = gen_one_crash_seq(cmds, reordered_cmds, seed);
    std::cout << "Crash point: " << crash_point << std::endl;
    
    // interpret_cmds("Reordered Trace", reordered_cmds, trace_file);

    bool state_changed = check_write_state_change(reordered_cmds[crash_point], trace_file);
    
    // select the latest checkpoint before the crash point
    s64 ckpt_point = -1;

    if (state_changed) {
        for (s64 i = crash_point; i >= 0; i--)
        {
            if (cmds[i].type == HK_CMD_CKPT)
            {
                ckpt_point = i;
                break;
            }
        }
    } else {
        ckpt_point = crash_point;
    }
    
    std::cout << "Check point: " << ckpt_point << std::endl;

    // create crash image
    create_image(reordered_cmds, crash_point, trace_file, crash_file);
    // create latest image
    create_image(reordered_cmds, ckpt_point, trace_file, latest_file);

    std::cout << "Image Created." << std::endl;

    if (ckpt_point == (s64)crash_point) {
        std::cout << "No need to do further check." << std::endl;
    }

    reordered_cmds.clear();

    cmds.clear();
    trace_file.close();
    crash_file.close();
    latest_file.close();
    return 0;
}