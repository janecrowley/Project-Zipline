#########################################################################
# Verisium Debug version 25.06.071-a (Built on 2025-07-15T09:25:56Z)
# history.py generated at 2025/08/20 14:03:24
# host: sjcvl-janec
# port: 36685
# launch command: indago -connect dc:sjcvl-janec.cadence.com:58351 -interactive
# #########################################################################
import time, os, sys
if 'self' not in globals():
    from verisium import *
    from verisium.embedded.embedded_utils import indago_help
    self = VerisiumDebugServer(VerisiumDebugArgs(
        is_gui=True,
        is_launch_needed=True,
        port=36685,
        extra_args='-connect dc:sjcvl-janec.cadence.com:58351 -interactive'
    ))

# Verisium: Attempting to connect to Verisium server on host: localhost, port: 36685
# Verisium: **************************************************************************************
# Verisium: *****                        Verisium version 25.06.071-a                        *****
# Verisium: *****                 NOTE: Some API features are Beta quality.                  *****
# Verisium: *****            Consult the <a href="api_reference/beta_apis.html" style="">API documentation</a> for more information.             *****
# Verisium: **************************************************************************************
# # Hint: Use 'self' to reference the running Verisium Debug server. (ex: self.server_info)
# >>> 