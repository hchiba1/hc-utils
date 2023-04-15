#!/usr/bin/env node
import {$} from 'zx'

$.verbose = false

const ret = await $`ls -l`
console.log(ret.stdout.trim());
