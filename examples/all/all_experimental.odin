#+build windows
package all

import c_tokenizer    "core:c/frontend/tokenizer"
import c_preprocessor "core:c/frontend/preprocessor"

_ :: c_tokenizer
_ :: c_preprocessor
