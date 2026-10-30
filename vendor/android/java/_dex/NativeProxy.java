package org.odin_lang;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

/**
 * Implements Java interfaces with an Odin procedure, through `java.lang.reflect.Proxy`.
 * See `proxy_new` in vendor:android/java, which also registers `call`.
 */
public final class NativeProxy implements InvocationHandler {
	private final long handler;
	private final long data;

	public NativeProxy(long handler, long data) {
		this.handler = handler;
		this.data    = data;
	}

	@Override
	public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
		// Object's own methods behave as they do for any other object.
		if (method.getDeclaringClass() == Object.class) {
			switch (method.getName()) {
			case "equals":   return proxy == args[0];
			case "hashCode": return System.identityHashCode(proxy);
			case "toString": return proxy.getClass().getName() + "@" + Integer.toHexString(System.identityHashCode(proxy));
			}
		}
		return call(handler, data, method, args);
	}

	private static native Object call(long handler, long data, Method method, Object[] args);
}
