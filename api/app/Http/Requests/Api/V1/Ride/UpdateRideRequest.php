<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Ride;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRideRequest extends FormRequest
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
            'distance_km' => ['sometimes', 'required', 'integer', 'min:1'],
            'started_at' => ['nullable', 'date'],
            'ended_at' => ['nullable', 'date', 'after_or_equal:started_at'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
