<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Bike;

use Illuminate\Foundation\Http\FormRequest;

class StoreBikeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'bike_model_id' => ['required', 'integer', 'exists:bike_models,id'],
            'serial_number' => ['nullable', 'string', 'max:255', 'unique:bikes,serial_number'],
            'frame_number' => ['nullable', 'string', 'max:255', 'unique:bikes,frame_number'],
            'nickname' => ['nullable', 'string', 'max:255'],
            'color' => ['nullable', 'string', 'max:255'],
            'odometer_km' => ['nullable', 'integer', 'min:0'],
            'purchased_at' => ['nullable', 'date'],
        ];
    }
}
