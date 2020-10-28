#!/bin/sh

DIR=$(dirname "$0")

cd $DIR

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

echo "Deleting old publication"
rm -rf public
mkdir public

echo "Generating site"
zola serve

echo "Synchronising Cloud"
gsutil -m rsync -d -r public gs://malramsay.com/
