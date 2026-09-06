#!/usr/bin/env php
<?php
/**
 * Twig syntax linter for the theme.
 *
 * Usage: php bin/twig-lint.php <theme-dir>
 *
 * Parses every .twig file under templates/ and views/ with the Twig compiler
 * (syntax only - unknown WordPress/Timber functions and filters are tolerated),
 * and checks that every template referenced by extends/include/embed exists.
 * Exit code 1 on any problem.
 */

declare(strict_types=1);

$theme = rtrim($argv[1] ?? '', '/');

if ('' === $theme || ! is_dir($theme)) {
    fwrite(STDERR, "Usage: php bin/twig-lint.php <theme-dir>\n");
    exit(2);
}

$autoload = $theme . '/vendor/autoload.php';

if (! is_file($autoload)) {
    fwrite(STDERR, "Missing {$autoload}. Run composer install first.\n");
    exit(2);
}

require $autoload;

$dirs = array_values(array_filter(
    [$theme . '/templates', $theme . '/views'],
    'is_dir'
));

$loader = new \Twig\Loader\FilesystemLoader($dirs);
$twig   = new \Twig\Environment($loader, ['cache' => false, 'strict_variables' => false]);

// Tolerate any function/filter name: WordPress + Timber provide them at runtime.
$twig->registerUndefinedFunctionCallback(
    static fn (string $name): \Twig\TwigFunction => new \Twig\TwigFunction($name, static fn () => null)
);
$twig->registerUndefinedFilterCallback(
    static fn (string $name): \Twig\TwigFilter => new \Twig\TwigFilter($name, static fn ($value = null) => $value)
);

$errors = 0;
$count  = 0;

foreach ($dirs as $dir) {
    $iterator = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($dir, \FilesystemIterator::SKIP_DOTS));

    foreach ($iterator as $file) {
        if ('twig' !== $file->getExtension()) {
            continue;
        }

        ++$count;
        $relative = substr($file->getPathname(), strlen($dir) + 1);
        $code     = (string) file_get_contents($file->getPathname());

        try {
            $twig->parse($twig->tokenize(new \Twig\Source($code, $relative, $file->getPathname())));
        } catch (\Twig\Error\SyntaxError $e) {
            ++$errors;
            fwrite(STDERR, sprintf("SYNTAX  %s:%d  %s\n", $file->getPathname(), $e->getTemplateLine(), $e->getRawMessage()));
            continue;
        }

        // Referenced templates must exist in one of the lookup directories.
        if (preg_match_all('/\{%-?\s*(?:extends|include|embed|import|from)\s+[\'"]([^\'"]+)[\'"]/', $code, $matches)) {
            foreach (array_unique($matches[1]) as $reference) {
                if (! $loader->exists($reference)) {
                    ++$errors;
                    fwrite(STDERR, sprintf("MISSING %s  references \"%s\" which does not exist\n", $file->getPathname(), $reference));
                }
            }
        }
    }
}

if ($errors > 0) {
    fwrite(STDERR, sprintf("\n%d problem(s) in %d Twig file(s).\n", $errors, $count));
    exit(1);
}

echo sprintf("Twig OK: %d template(s) parsed, all references resolve.\n", $count);
