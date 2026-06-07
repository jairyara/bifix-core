<?php

declare(strict_types=1);

use App\Http\Controllers\Api\V1\Auth\LoginController;
use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\ProfileController;
use App\Http\Controllers\Api\V1\Auth\RegisterController;
use App\Http\Controllers\Api\V1\Bike\BikeController;
use App\Http\Controllers\Api\V1\Catalog\BatteryTypeController;
use App\Http\Controllers\Api\V1\Catalog\BikeModelController;
use App\Http\Controllers\Api\V1\Catalog\BrandController;
use App\Http\Controllers\Api\V1\Ride\RideController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.v1.')->group(function (): void {
    Route::get('health', fn () => response()->json([
        'status' => 'ok',
        'service' => 'bifix-api',
    ]))->name('health');

    Route::prefix('auth')->name('auth.')->group(function (): void {
        Route::middleware('throttle:10,1')->group(function (): void {
            Route::post('register', RegisterController::class)->name('register');
            Route::post('login', LoginController::class)->name('login');
        });

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::get('me', ProfileController::class)->name('me');
            Route::post('logout', LogoutController::class)->name('logout');
        });
    });

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('brands', [BrandController::class, 'index'])->name('brands.index');
        Route::get('brands/{brand}', [BrandController::class, 'show'])->name('brands.show');
        Route::get('bike-models', [BikeModelController::class, 'index'])->name('bike-models.index');
        Route::get('bike-models/{bikeModel}', [BikeModelController::class, 'show'])->name('bike-models.show');
        Route::get('battery-types', [BatteryTypeController::class, 'index'])->name('battery-types.index');
        Route::apiResource('bikes', BikeController::class);
        Route::apiResource('bikes.rides', RideController::class);
    });
});
