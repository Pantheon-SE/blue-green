<?php

$num_bytes = 10737418240; // 10 GB in total
$chunk_size = 1000000; // 1 MB per chunk
$num_chunks = $num_bytes / $chunk_size;

function formatBytes($bytes, $precision = 2)
{
    $units = array('B', 'KB', 'MB', 'GB', 'TB');

    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);

    // Uncomment one of the following alternatives
    // $bytes /= pow(1024, $pow);
    // $bytes /= (1 << (10 * $pow)); 

    return round($bytes, $precision) . ' ' . $units[$pow];
}

echo "<pre>";

while ($num_bytes > 0) {

    // Create a random directory name
    $dirname = '/files/dir-' . mt_rand(0, 25);
    mkdir($dirname);

    $chunk_size = mt_rand(1000000, 5000000);
    $num_bytes = $num_bytes - $chunk_size;

    // Write the random data to a file
    $random_data = openssl_random_pseudo_bytes($chunk_size);
    $random_file = $dirname . '/random-' . uniqid() . '.dat';
    file_put_contents($random_file, $random_data);

    $byte_size = formatBytes($chunk_size);
    echo "$random_file: $byte_size \n";

}

echo "</pre>";