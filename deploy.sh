#!/bin/bash

scp -r public/* deploy@axon.ranvier.net:/neuron/srv/web/blog/

exit 0
