//
//  nouveau_definitions.h
//  HWSensors
//
//  Created by Kozlek on 07.08.12.
//
//

#ifndef HWSensors_nouveau_definitions_h
#define HWSensors_nouveau_definitions_h

#include "linux_definitions.h"

//#define NV_DEBUG_ENABLED false
#define NV_TRACE_ENABLED false
#define NV_SPAM_ENABLED false

#define nv_prefix "GeForceSensors"

#define nv_fatal(o,f,a...) do { if (1) { IOLog ("%s (%d): [Fatal] " f, nv_prefix, (o)->card_index, ##a); } } while(0)
#define nv_error(o,f,a...) do { if (1) { IOLog ("%s (%d): [Error] " f, nv_prefix, (o)->card_index, ##a); } } while(0)
#define nv_warn(o,f,a...) do { if (1) { IOLog ("%s (%d): [Warning] " f, nv_prefix, (o)->card_index, ##a); } } while(0)
#define nv_info(o,f,a...) do { if (1) { IOLog ("%s (%d): " f, nv_prefix, o->card_index, ##a); } } while(0)
#define nv_debug(o,f,a...) do { if (NV_DEBUG_ENABLED) { IOLog ("%s (%d): [Debug] " f, nv_prefix, (o)->card_index, ##a); } } while(0)
#define nv_trace(o,f,a...) do { if (NV_TRACE_ENABLED) { IOLog ("%s (%d): [Trace] " f, nv_prefix, (o)->card_index, ##a); } } while(0)
#define nv_spam(o,f,a...) do { if (NV_SPAM_ENABLED) { IOLog ("%s (%d): [Spam] " f, nv_prefix, (o)->card_index, ##a); } } while(0)

#endif
