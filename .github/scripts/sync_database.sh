#!/bin/bash -e

# Required variables
# - BLUE_SITE
# - GREEN_SITE

terminus backup:create $BLUE_SITE --element=db --keep-for=1
BLUE_SITE_DB_URL=$(terminus backup:get ${BLUE_SITE} --element=db)
terminus import:database $GREEN_SITE $BLUE_SITE_DB_URL -y
