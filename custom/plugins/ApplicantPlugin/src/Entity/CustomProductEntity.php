<?php

namespace ApplicantPlugin\Entity;

use Shopware\Core\Content\Product\ProductEntity as BaseProductEntity;

/**
 * @ORM\Entity
 */
class CustomProductEntity extends BaseProductEntity
{

    /**
     * @var int
     */
    protected $viewCount = 0;


    public function getViewCount(): int
    {
        return $this->viewCount;
    }

    public function setViewCount(int $viewCount)
    {
        $this->viewCount = $viewCount;
        return $this;
    }

}