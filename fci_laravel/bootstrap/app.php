<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Symfony\Component\HttpKernel\Exception\HttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        commands: __DIR__ . '/../routes/console.php',
        api: __DIR__ . '/../routes/api.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // No CSRF protection for API routes
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (\Illuminate\Http\Request $request, \Throwable $e) {
            if ($request->is('api/*')) {
                if ($e instanceof HttpException) {
                    return response()->json(['error' => $e->getMessage()], $e->getStatusCode());
                }
                return response()->json(['error' => 'Something went wrong'], 500);
            }
        });
    })->create();
