package com.watchn.ui.services.carts;

import com.watchn.ui.services.carts.model.Cart;
import com.watchn.ui.services.carts.model.CartItem;
import com.watchn.ui.services.catalog.CatalogService;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class MockCartsService implements CartsService {

    private CatalogService catalogService;

    private Map<String, Cart> carts;

    public MockCartsService(CatalogService catalogService) {
        this.catalogService = catalogService;

        this.carts = new HashMap<>();
    }

    @Override
    public Mono<Cart> getCart(String sessionId) {
        return Mono.just(getOrCreate(sessionId));
    }

    private Cart getOrCreate(String sessionId) {
        Cart cart;

        if(!carts.containsKey(sessionId)) {
            cart = new Cart(new ArrayList<>());

            this.carts.put(sessionId, cart);
        }
        else {
            cart = carts.get(sessionId);
        }

        return cart;
    }

    @Override
    public Mono<Cart> deleteCart(String sessionId) {
        return null;
    }

    @Override
    public Mono<Void> addItem(String sessionId, String productId) {
        Cart cart = getOrCreate(sessionId);

        return this.catalogService.getProduct(productId)
                .map(p -> new CartItem(productId, 1, p.getPrice(), p.getName(), p.getImageUrl()))
                .doOnNext(i -> cart.addItem(i)).then();
    }

    @Override
    public Mono<Void> removeItem(String sessionId, String productId) {
        getOrCreate(sessionId).removeItem(productId);

        return Mono.empty();
    }
}
