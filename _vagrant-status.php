#!/usr/bin/env php
<?php

ini_set('display_errors', 1);

exec('/usr/local/bin/vagrant global-status | grep virtualbox', $output);

$final   = [];
$longest = 0;

foreach ($output as $line) {
    $bits = explode(' ', $line);
    $path = empty($bits[5]) ? $bits[6] : $bits[5];
    $longest = max(strlen($bits[4]), $longest);
    $final[$path] = $bits[4];
}

foreach ($final as $status => $path) {
    echo str_pad($path, $longest + 1, ' ', STR_PAD_RIGHT) . '- ' . $status . PHP_EOL;
}

