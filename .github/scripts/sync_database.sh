#!/bin/bash -e

# Required variables
# - BLUE_SITE_NAME
# - BLUE_SITE_ENV
# - GREEN_SITE_NAME
# - GREEN_SITE_ENV

terminus backup:create $BLUE_SITE_NAME.$BLUE_SITE_ENV --element=db --keep-for=1
BLUE_SITE_DB_URL=$(terminus backup:get $BLUE_SITE_NAME.$BLUE_SITE_ENV --element=db)
terminus import:database $GREEN_SITE_NAME.$GREEN_SITE_ENV $BLUE_SITE_DB_URL -y
