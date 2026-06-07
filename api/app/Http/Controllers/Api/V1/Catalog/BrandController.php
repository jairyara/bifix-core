<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\BrandResource;
use App\Models\Brand;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BrandController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $brands = Brand::query()
            ->orderBy('name')
            ->get();

        return BrandResource::collection($brands);
    }

    public function show(Brand $brand): JsonResponse
    {
        return response()->json([
            'data' => new BrandResource($brand),
        ]);
    }
}
