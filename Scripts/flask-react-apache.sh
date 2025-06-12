#!/bin/bash

PROJECT_DIR="$(pwd)/repo"
APACHE_DIR=/var/www/sitename
BRANCH=enterbranchofrepo
REPO=entergithubrepo
BACKEND_SERVER="api"
 
# Delete old project if -d flag is passed
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) echo "Deleting Project"; rm -rf $PROJECT_DIR; echo "Deleting Apache Directory"; rm -rf $APACHE_DIR;;
    esac
    shift
done

if [ -d $PROJECT_DIR ]; then
    echo
    echo "Project Directory has been created already"
    echo
else
    mkdir -p $PROJECT_DIR
    mkdir -p $APACHE_DIR
    echo "Project Directory was created just now: $PROJECT_DIR"
    echo "Apache Directory was created just now: $APACHE_DIR"
    git clone $REPO $PROJECT_DIR
fi

temp=$(pwd)

# Changing to development directory
cd $PROJECT_DIR
echo "SOURCE CONTROL -- Checking if development branch exists...."
git fetch origin
git ls-remote --heads origin $BRANCH
echo "SOURCE CONTROL -- Checking to the following branch: $BRANCH"
git checkout -b production origin/production

# frontend
echo "*===== CONFIGURING FRONTEND... =====*"
cd "$PROJECT_DIR/frontend" || { echo "FRONTEND ERROR ABORT"; exit 1; }
echo "FRONTEND -- Installing packages ..."
npm install
echo "FRONTEND -- Configuring backend server ..."
sed -i "s|http://localhost:5000|/$BACKEND_SERVER|g" "$PROJECT_DIR/frontend/src/config.tsx"
echo "FRONTEND -- Running Build..."
npm run build
echo "FRONTEND -- Generated dist/"
rm -f "$PROJECT_DIR/frontend/dist/*"
if [ -f vite.pid ]; then
    kill $(cat vite.pid) 2>/dev/null || true
    rm -f vite.pid
fi
touch vite.pid
echo "FRONTEND -- Attempting to run development environment..."
nohup sh -c "npm run dev --host 0.0.0.0 > vite.log 2>&1" &
echo $! > vite.pid
echo "FRONTEND -- This is the vite ID:"
echo $(cat vite.pid)
echo "FRONTEND -- Copying dist to $APACHE_DIR"
cp -r "$PROJECT_DIR/frontend/dist/"* "$APACHE_DIR"/
if [ ! -d dist ]; then { echo "Build failed!"; exit 1; } fi

# backend
"*===== CONFIGURING FRONTEND... =====*"
echo "Insert API Key"
read SEC_API_KEY
echo "SRC_API_KEY=$SEC_API_KEY" > "$PROJECT_DIR/backend/.env"
cd "$PROJECT_DIR/backend" || { echo "BACKEND ERROR ABORT"; exit 2; }
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
if [ -f flask.pid ]; then
    kill $(cat flask.pid) 2>/dev/null || true
    rm -f flask.pid
fi
touch flask.pid
nohup python server.py > flask.log 2>&1 &
echo $! > flask.pid
echo "This is the flask PID: "
echo $(cat flask.pid)
echo "*===== DEPLOYMENT COMPLETE =====*
