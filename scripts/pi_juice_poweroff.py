#!/usr/bin/python3

import os
import logging
from logging.handlers import RotatingFileHandler
from time import sleep
from pijuice import PiJuice

# create logger
logger = logging.getLogger('simple_logger')

# set logging level
logger.setLevel(logging.DEBUG)

# create rotating file handler and set level to debug
handler = RotatingFileHandler('/home/steve/pijuice/power.log', maxBytes=5242880, backupCount=3)
handler.setLevel(logging.DEBUG)

# create formatter
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# add formatter to rotating file handler
handler.setFormatter(formatter)

# add ch to logger
logger.addHandler(handler)

# ensure PI juice is functioning
pj = PiJuice(1,0x14)

pjOK = False
while pjOK == False:
   stat = pj.status.GetStatus()
   if stat['error'] == 'NO_ERROR':
      pjOK = True
   else:
      sleep(0.1)

logger.info('Powering off')

# configure wake up for 5am local (times need to be in UTC)
alarm = {}
alarm['second'] = 0
alarm['minute'] = 0
alarm['day'] = 'EVERY_DAY'
# 5am in Australia/Sydney
alarm['hour'] = 18
status = pj.rtcAlarm.SetAlarm(alarm)

if status['error'] != 'NO_ERROR':
    logger.info(' - failed to apply wakeup alarm options. Error: {}'.format(status['error']))

sleep(1)

# Make sure wakeup_enabled, in my situation the battery is external so we don't want wakup on charge set
pj.rtcAlarm.SetWakeupEnabled(True)
# pj.power.SetWakeUpOnCharge(0)

# Make sure power to the Raspberry Pi is stopped to not deplete the battery
pj.power.SetSystemPowerSwitch(0)

# Give the pi some time to shutdown
pj.power.SetPowerOff(30)

# Now turn off the system
os.system("sudo shutdown -h now")
