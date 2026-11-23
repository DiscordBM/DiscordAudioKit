#ifndef OPUS_SHIMS_H
#define OPUS_SHIMS_H

#include "opus.h"

#ifdef __cplusplus
extern "C" {
#endif

int opus_encoder_set_ctl_int(OpusEncoder *st, int request, opus_int32 value);
int opus_encoder_get_ctl_int(OpusEncoder *st, int request, opus_int32 *value);
int opus_decoder_set_ctl_int(OpusDecoder *st, int request, opus_int32 value);
int opus_decoder_get_ctl_int(OpusDecoder *st, int request, opus_int32 *value);

#ifdef __cplusplus
}
#endif

#endif /* OPUS_SHIMS_H */
