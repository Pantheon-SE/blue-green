#!/bin/bash

cat << EOF > test.txt

GREEN_SITE_ENV=$GREEN_SITE_ENV
GREEN_SITE_ID=$GREEN_SITE_ID
BLUE_SITE_ENV=$BLUE_SITE_ENV
BLUE_SITE_ID=$BLUE_SITE_ID

EOF

#debug
cat test.txt

# Run deployment based on target environment.
if [[ "$GREEN_SITE_ENV" == "live" ]]; then
    # Test deploy first.
    terminus env:deploy $GREEN_SITE_ID.test --updatedb --note="Deploy trigger from GitHub Actions" -y
    terminus env:clear-cache $GREEN_SITE_ID.test

    # Then live deploy.
    terminus env:deploy $GREEN_SITE_ID.live --updatedb --note="Deploy trigger from GitHub Actions" -y
    terminus env:clear-cache $GREEN_SITE_ID.live

    # Swap site traffic.
    terminus drush $GREEN_SITE_ID.$GREEN_SITE_ENV -- vset --yes maintenance_mode 0;
    terminus drush $GREEN_SITE_ID.$GREEN_SITE_ENV -- cc all;

    terminus drush $BLUE_SITE_ID.$BLUE_SITE_ENV -- vset --yes maintenance_mode 1;
    terminus drush $BLUE_SITE_ID.$BLUE_SITE_ENV -- cc all;
else
    echo "Not deploying to live environment. Skipping."
fi
