#!/bin/bash

bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
sed -i 's/^OSH_THEME=.*/OSH_THEME="agnoster"/' ~/.bashrc
