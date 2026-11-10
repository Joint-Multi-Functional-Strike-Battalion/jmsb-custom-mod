# libopus (built by the opus crate through cmake) with the static C runtime,
# /MT, like the rest of the DLL (config.toml). Its build has the switch but
# the crate never sets it, and a /MD libopus does not link here.
set(OPUS_STATIC_RUNTIME ON CACHE BOOL "libopus links the static C runtime" FORCE)
