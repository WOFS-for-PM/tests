#include "common.h"

#define FILE_PATH "/mnt/pmem0/test"
#define TEST_SIZE (4L * 1024 * 1024 * 1024)

void pmem_warmup(void *pm_addr, size_t size)
{
    size_t i;
    for (i = 0; i < size; i += 1) {
        *((char *)pm_addr + i) = 0;
    }
}

u_int64_t pmem_space_setup()
{
    size_t mapped_len;
    int is_pmem;
    u_int64_t pm_addr;

    if ((pm_addr = (u_int64_t)pmem_map_file(FILE_PATH, TEST_SIZE, PMEM_FILE_CREATE, 0777, &mapped_len, &is_pmem)) == 0) {
        perror("pmem_space_setup");
        exit(1);
    }

    if (!is_pmem) {
        printf("%s is not a pmem file\n", FILE_PATH);
        exit(1);
    }

    pmem_warmup((void *)pm_addr, TEST_SIZE);

    return pm_addr;
}

void pmem_space_unset(u_int64_t pm_addr)
{
    pmem_unmap((void *)pm_addr, TEST_SIZE);
}

const char *tokens[] = {"-link", "-log", "-each", "-threads", "-size"};
enum TOKEN_ID { LINK,
                LOG,
                EACH,
                THREADS,
                SIZE };

struct cmd {
    u_int64_t each;
    u_int8_t threads;
    u_int64_t size;
    u_int8_t type;
};

void *perform_write(void *arg)
{
    struct wr_param *param = (struct wr_param *)arg;

    off_t ofs = param->ofs;
    size_t each = param->each;
    size_t size = param->size;
    unsigned char *content = param->content;
    u_int64_t pm_addr = param->pm_addr;
    write_iter write_func = param->write_func;

    u_int64_t target_addr;
    int count = size / each;
    int i;
    
    target_addr = pm_addr + ofs;
    for (i = 0; i < count; i++) {
        write_func(pm_addr, target_addr, content, each, size);
        target_addr += each;
    }
}

int main(int argc, char const *argv[])
{
    struct wr_param *params;
    struct cmd cmd;
    const char *token;
    pthread_t *tids;
    u_int64_t per_thread_size;
    struct timeval time_start;
    struct timeval time_end;
    unsigned long diff;
    size_t i;
    u_int64_t pm_addr;
    unsigned char *content;

    pm_addr = pmem_space_setup();

    cmd.type = LOG;
    cmd.size = 4L * 1024 * 1024 * 1024; /* 4G default */
    cmd.threads = 1;
    cmd.each = 4 * 1024; /* 4K default */

    i = 0;
    while (++i < argc) {
        token = argv[i];
        if (strcmp(token, tokens[LINK]) == 0)
            cmd.type = LINK;
        else if (strcmp(token, tokens[LOG]) == 0)
            cmd.type = LOG;
        else if (strcmp(token, tokens[EACH]) == 0)
            cmd.each = atoi(argv[++i]);
        else if (strcmp(token, tokens[THREADS]) == 0)
            cmd.threads = atoi(argv[++i]);
        else if (strcmp(token, tokens[SIZE]) == 0)
            cmd.size = atoll(argv[++i]);
    }

    tids = malloc(sizeof(pthread_t) * cmd.threads);
    params = malloc(sizeof(struct wr_param) * cmd.threads);
    content = malloc(cmd.each);
    per_thread_size = cmd.size / cmd.threads;

    printf("Test with CMD: \n type: %s \n size: %lu \n threads: %u \n each: %lu \n per_thread_size: %llu \n\n",
           cmd.type == LOG ? "LOG" : "LINK", cmd.size, cmd.threads, cmd.each, per_thread_size);

    printf("Prepare to write...\n");
    for (i = 0; i < cmd.threads; i++) {
        params[i].ofs = i * per_thread_size;
        params[i].size = per_thread_size;
        params[i].pm_addr = pm_addr;
        params[i].each = cmd.each;
        params[i].content = content;
        switch (cmd.type) {
        case LINK:
            params[i].write_func = link_write;
            break;
        case LOG:
            params[i].write_func = log_write;
            break;
        default:
            break;
        }
    }

    void *measure;
    float imc_rd, imc_wr, media_rd, media_wr;

    printf("Start writing...\n");
    measure = PmmDataCollector_new("PM data", &imc_rd, &imc_wr, &media_rd, &media_wr);
    
    gettimeofday(&time_start, NULL);
    for (i = 0; i < cmd.threads; i++) {
        pthread_create(&tids[i], NULL, perform_write, &params[i]);
    }
    printf("Wait writing...\n");
    for (i = 0; i < cmd.threads; i++) {
        pthread_join(tids[i], NULL);
    }
    gettimeofday(&time_end, NULL);
    
    PmmDataCollector_delete(measure);
    
    diff = (time_end.tv_sec * 1000 * 1000 + time_end.tv_usec) - (time_start.tv_sec * 1000 * 1000 + time_start.tv_usec);

    free(tids);
    free(params);
    free(content);
    pmem_space_unset(pm_addr);

    printf("Write in %lu ms\n", diff / 1000);
    printf("Bandwidth: %.2f MB/s\n", (cmd.size * 1000 * 1000 / 1024.0 / 1024.0) / diff);
    return 0;
}
