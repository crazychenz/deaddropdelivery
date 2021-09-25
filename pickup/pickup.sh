#!/bin/bash

IDENTITY_FPATH=/projects/cicd/deaddropdelivery/pickup/ssh/id_rsa
PICKUP_FPATH=/projects/cicd/deaddropdelivery/pickup/
REPOPREFIX=/projects/cicd/
REPONAME=$1
REPOHASH=$(echo -n "$REPONAME" | sha1sum | awk '{print $1}')
echo REPOHASH: $REPOHASH

#rm state/*
if [ ! -e $PICKUP_FPATH/state/$REPOHASH-prev-pickup ]; then
  echo No existing state, creating a new one.
  echo 0 > $PICKUP_FPATH/state/$REPOHASH-prev-pickup
fi

# This fetches the prev pickup time (that we don't want)
PREV_PICKUP=$(cat $PICKUP_FPATH/state/$REPOHASH-prev-pickup)

# This is the command to fetch the commit data.
JOB=$(curl -s -X GET $(cat $PICKUP_FPATH/pickup-url.cfg)/$REPOHASH/$PREV_PICKUP)
if [ $? -ne 0 ]; then
  echo "Failed to fetch data from pickup end point. Exiting."
  exit 1
fi

# Stop process if no new jobs to do.
if [ -z "$JOB" ]; then
  echo No new code to test, exiting.
  exit 0;
fi

# This is the return with "request/" stripped.
VALUE=$(echo $JOB | cut -d '/' -f2)

# Log that we got this commit so we don't attempt another fetch.
echo $VALUE | cut -d '-' -f2 > $PICKUP_FPATH/state/$REPOHASH-prev-pickup

# This is the commit that we want to checkout
THIS_PICKUP_COMMIT=$(echo $VALUE | cut -d '-' -f3)

if [ ! -e $REPOHASH ]; then
  echo No clone of repo, cloning now.
  GIT_SSH_COMMAND="ssh -i $IDENTITY_FPATH" \
    git clone git@github.com:$REPONAME.git $REPOPREFIX$REPOHASH
  #git clone https://github.com/$REPONAME.git $REPOPREFIX$REPOHASH
  if [ $? -ne 0 ]; then
    echo "Failed to clone repository. Exiting."
    exit 1
  fi
fi

pushd $REPOPREFIX$REPOHASH >/dev/null

  echo Pulling $REPONAME
  GIT_SSH_COMMAND="ssh -i $IDENTITY_FPATH" git pull 2>/dev/null
  #if [ $? -ne 0 ]; then
  #  echo "$? Failed to pull repository updates. Exiting."
  #  exit 1
  #fi

  echo Checking out $THIS_PICKUP_COMMIT.
  git checkout $THIS_PICKUP_COMMIT 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to checkout this commit. Exiting."
    exit 1
  fi

  if [ -e deaddropdelivery.sh ]; then
    echo Starting CI/CD script.
    # TODO: Consider adding a timeout.
    ./deaddropdelivery.sh
    if [ $? -ne 0 ]; then
      echo "Failed to complete CI/CD script. Exiting."
      exit 1
    fi
  fi

popd >/dev/null


exit 0


