<?php
/**
 * Generate a Lions-styled placeholder JPEG for demo content.
 *
 * The theme ships SVG placeholders (assets/images/placeholders/), but a
 * featured image has to be a real attachment in the media library, and
 * WordPress does not accept SVG uploads. This draws the same artwork as a
 * raster image so `make install` can seed featured images without committing
 * binary files to the repository.
 *
 * Usage: php bin/placeholder-image.php <output.jpg> [width] [height] [variant]
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

$out     = $argv[1] ?? '';
$width   = (int) ( $argv[2] ?? 1200 );
$height  = (int) ( $argv[3] ?? 800 );
$variant = (int) ( $argv[4] ?? 0 );

if ( '' === $out ) {
	fwrite( STDERR, "Usage: placeholder-image.php <output.jpg> [width] [height] [variant]\n" );
	exit( 1 );
}

// Design tokens (assets/css/tokens.css).
$navy    = array( 0x11, 0x2E, 0x57 ); // --color-navy-700
$blue    = array( 0x0A, 0x3D, 0xAB ); // --color-primary
$accents = array(
	array( 0xF9, 0xC9, 0x10 ), // --color-accent
	array( 0x8B, 0x29, 0x94 ), // --color-purple
	array( 0x3F, 0x9D, 0x5A ), // --color-green
	array( 0x3A, 0x75, 0xC4 ), // --color-primary-light
);
$accent = $accents[ $variant % count( $accents ) ];

$image = imagecreatetruecolor( $width, $height );
imagealphablending( $image, true );

// Diagonal gradient, navy to Lions blue, drawn as anti-diagonal lines.
$steps = $width + $height;
for ( $i = 0; $i < $steps; $i++ ) {
	$t     = $i / ( $steps - 1 );
	$color = imagecolorallocate(
		$image,
		(int) round( $navy[0] + ( $blue[0] - $navy[0] ) * $t ),
		(int) round( $navy[1] + ( $blue[1] - $navy[1] ) * $t ),
		(int) round( $navy[2] + ( $blue[2] - $navy[2] ) * $t )
	);
	imageline( $image, $i, 0, 0, $i, $color );
}

$scale = $width / 800;

// Dot pattern.
$dot  = imagecolorallocatealpha( $image, 0xFF, 0xFF, 0xFF, 105 );
$step = (int) round( 28 * $scale );
$r    = max( 1, (int) round( 1.6 * $scale ) );
for ( $y = $step; $y < $height; $y += $step ) {
	for ( $x = $step; $x < $width; $x += $step ) {
		imagefilledellipse( $image, $x, $y, $r * 2, $r * 2, $dot );
	}
}

// Soft shapes, offset per variant so seeded posts do not all look identical.
$shift = ( $variant % 3 ) * 60 * $scale;
$veil  = imagecolorallocatealpha( $image, 0xFF, 0xFF, 0xFF, 117 );
imagefilledellipse( $image, (int) ( 600 * $scale - $shift ), (int) ( 166 * $scale ), (int) ( 332 * $scale ), (int) ( 332 * $scale ), $veil );

$glow = imagecolorallocatealpha( $image, $accent[0], $accent[1], $accent[2], 83 );
imagefilledellipse( $image, (int) ( 160 * $scale + $shift ), (int) ( 400 * $scale ), (int) ( 250 * $scale ), (int) ( 250 * $scale ), $glow );

$band = imagecolorallocatealpha( $image, $accent[0], $accent[1], $accent[2], 96 );
imagefilledpolygon(
	$image,
	array(
		0, $height,
		(int) ( 320 * $scale ), $height,
		(int) ( 480 * $scale ), (int) ( 275 * $scale ),
		0, (int) ( 350 * $scale ),
	),
	$band
);

$corner = imagecolorallocatealpha( $image, 0xFF, 0xFF, 0xFF, 122 );
imagefilledpolygon(
	$image,
	array(
		$width, 0,
		$width, (int) ( 225 * $scale ),
		(int) ( 496 * $scale ), 0,
	),
	$corner
);

if ( ! imagejpeg( $image, $out, 82 ) ) {
	fwrite( STDERR, "Could not write $out\n" );
	exit( 1 );
}

imagedestroy( $image );
