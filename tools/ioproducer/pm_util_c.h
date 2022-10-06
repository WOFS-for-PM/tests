#ifdef __cplusplus
extern "C" {
#endif

extern void *PmmDataCollector_new(char *name, float *real_imc_read, float *real_imc_write, float *real_media_read, float *real_media_write);
extern void PmmDataCollector_delete(void *collector);

#ifdef __cplusplus
}
#endif