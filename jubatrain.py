#!/usr/bin/env python

host = '127.0.0.1'
port = 9199
cluster = 'test'

import jubatus
import jubatus.classifier.types
import sys

client = jubatus.Classifier(host, port)

for line in sys.stdin:
    ss = line.split(' ')
    label = ss[0]
    num_values = []
    for s in ss[1:]:
        (key, value) = s.split(':')
        num_values.append((key, value))

    data = jubatus.classifier.types.datum([], num_values)
    client.train(cluster, [(label, data)])
