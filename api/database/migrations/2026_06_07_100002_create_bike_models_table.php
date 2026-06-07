<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bike_models', function (Blueprint $table) {
            $table->id();
            $table->foreignId('brand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('battery_type_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('slug');
            $table->unsignedSmallInteger('year')->nullable();
            $table->string('frame_type')->nullable();
            $table->string('motor_brand')->nullable();
            $table->unsignedInteger('battery_wh')->nullable();
            $table->unsignedInteger('range_km')->nullable();
            $table->timestamps();

            $table->unique(['brand_id', 'slug']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bike_models');
    }
};
