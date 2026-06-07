<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Bike;

use App\Models\Bike;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBikeRequest extends FormRequest
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
        /** @var Bike $bike */
        $bike = $this->route('bike');

        return [
            'bike_model_id' => ['sometimes', 'required', 'integer', 'exists:bike_models,id'],
            'serial_number' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('bikes', 'serial_number')->ignore($bike->id),
            ],
            'frame_number' => [
                'nullable',
                'string',
                'max:255',
                Rule::unique('bikes', 'frame_number')->ignore($bike->id),
            ],
            'nickname' => ['nullable', 'string', 'max:255'],
            'color' => ['nullable', 'string', 'max:255'],
            'odometer_km' => ['nullable', 'integer', 'min:0'],
            'purchased_at' => ['nullable', 'date'],
        ];
    }
}
