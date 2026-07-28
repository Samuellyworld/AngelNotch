#pragma once

#include <stdbool.h>

bool ANLaunchAtLoginIsEnabled(void);
bool ANLaunchAtLoginRequiresApproval(void);
bool ANSetLaunchAtLoginEnabled(bool enabled);
const char *ANLaunchAtLoginLastError(void);
