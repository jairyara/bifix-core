<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\BikeModelResource;
use App\Models\BikeModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BikeModelController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $bikeModels = BikeModel::query()
            ->when(
                $request->filled('brand_id'),
                fn ($query) => $query->where('brand_id', $request->integer('brand_id')),
            )
            ->with(['brand', 'batteryType'])
            ->orderBy('name')
            ->get();

        return BikeModelResource::collection($bikeModels);
    }

    public function show(BikeModel $bikeModel): JsonResponse
    {
        $bikeModel->load(['brand', 'batteryType']);

        return response()->json([
            'data' => new BikeModelResource($bikeModel),
        ]);
    }
}
