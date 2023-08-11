<?php

namespace ApplicantPlugin\Command;

use Shopware\Core\Framework\Context;
use Shopware\Storefront\Page\Product\ProductPageLoader;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;


class MostViewedProductsReportCommand extends Command
{
    protected static $defaultName = 'applicant_plugin:most-viewed-products';

    private ProductPageLoader $productPageLoader;

    public function __construct(
        ProductPageLoader $productPageLoader,
    ) {
        parent::__construct();
        $this->productPageLoader = $productPageLoader;
    }

    protected function configure()
    {
        $this->setDescription('Generate a report of the most viewed products');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $context = Context::createDefaultContext();
        $productPages = $this->productPageLoader->load($context);

        $productViews = [];
        foreach ($productPages as $productPage) {
            $product = $productPage->getProduct();
            $viewCount = $product->getViewCount();
            $productViews[$product->getId()] = [
                'id' => $product->getId(),
                'name' => $product->getTranslation('name'),
                'views' => $viewCount,
            ];
        }

        usort($productViews, function ($a, $b) {
            return $b['views'] - $a['views'];
        });

        foreach ($productViews as $productView) {
            $output->writeln("Product ID: {$productView['id']}, Name: {$productView['name']}, Views: {$productView['views']}");
        }

        return Command::SUCCESS;
    }
}