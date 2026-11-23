#include "opus_shims.h"

int opus_encoder_set_ctl_int(OpusEncoder *st, int request, opus_int32 value) {
    return opus_encoder_ctl(st, request, value);
}

int opus_encoder_get_ctl_int(OpusEncoder *st, int request, opus_int32 *value) {
    return opus_encoder_ctl(st, request, value);
}

int opus_decoder_set_ctl_int(OpusDecoder *st, int request, opus_int32 value) {
    return opus_decoder_ctl(st, request, value);
}

int opus_decoder_get_ctl_int(OpusDecoder *st, int request, opus_int32 *value) {
    return opus_decoder_ctl(st, request, value);
}
