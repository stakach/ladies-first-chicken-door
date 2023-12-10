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

# give the OS and services some time to init
sleep(10)

logger.info('Enabling wakeup timer')

# Make sure wakeup_enabled, independently configured to wake up at 5am
pj.rtcAlarm.SetWakeupEnabled(True)
