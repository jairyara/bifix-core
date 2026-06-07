<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.v1.')->group(function (): void {
    Route::get('health', fn () => response()->json([
        'status' => 'ok',
        'service' => 'bifix-api',
    ]))->name('health');
});
