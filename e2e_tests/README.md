# Setup

        source env/bin/activate
        pip install -r requirements.txt
        rfbrowser init

# Getting completion in vscode

- I don't actually know how to configure this properly
- I just do the setup without the venv ngl

# Running the services in e2e environment

(Requires db running)

        MIX_ENV=e2e mix setup
        MIX_ENV=e2e mix phx.server

# Running tests

        source env/bin/activate
        robot --outputdir output features

# Exiting venv

        deactivate

# Upgrading robot

        pip install --upgrade robotframework
