<?php

namespace ApplicantPlugin\Subscriber;

use Doctrine\Persistence\ManagerRegistry;
use Shopware\Storefront\Page\Product\ProductPageLoadedEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Shopware\Core\Framework\DataAbstractionLayer\EntityRepository;


class ProductPageLoadedSubscriber implements EventSubscriberInterface
{
    private EntityRepository $productRepository;

    public function __construct(EntityRepository $productRepository)
    {
        $this->productRepository = $productRepository;
    }

    public static function getSubscribedEvents(): array
    {
        return [
            ProductPageLoadedEvent::class => 'onProductPageLoaded',
        ];
    }

    public function onProductPageLoaded(ProductPageLoadedEvent $event): void
    {
        $product = $event->getPage()->getProduct();

        $views = $product->getViewCount();
        $product->setViewCount($views + 1);

        $this->productRepository->update([
            [
                'id' => $product->getId(),
                'view_count' => $product->getViewCount(),
            ]
        ], $event);
    }
}