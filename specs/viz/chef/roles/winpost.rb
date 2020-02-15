# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
# Licensed under the MIT License.
# 
name "winpost"
description "Install some pre/post software install Role"
run_list("recipe[chocolatey::default]", "recipe[winpost]")

