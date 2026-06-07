<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bikes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bike_model_id')->constrained()->restrictOnDelete();
            $table->string('serial_number')->nullable()->unique();
            $table->string('frame_number')->nullable()->unique();
            $table->string('nickname')->nullable();
            $table->string('color')->nullable();
            $table->unsignedInteger('odometer_km')->nullable();
            $table->date('purchased_at')->nullable();
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bikes');
    }
};
