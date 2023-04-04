#include "pm_util_c.h"
#include "pm_util.h"
 
extern void *PmmDataCollector_new(char *name, float *real_imc_read, float *real_imc_write, float *real_media_read, float *real_media_write) {
    return new util::PmmDataCollector(name, real_imc_read, real_imc_write, real_media_read, real_media_write);
}
 
extern void PmmDataCollector_delete(void *collector) {
    util::PmmDataCollector *c = (util::PmmDataCollector *)collector;
    delete c;
}