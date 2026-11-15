package org.odin_lang;

import android.content.Intent;

import java.util.concurrent.CopyOnWriteArrayList;

/**
 * A NativeActivity that also passes on what Android only tells an activity's Java methods.
 * `odin bundle android` puts this class in every app, so a manifest can name it instead of
 * `android.app.NativeActivity`. Implement `Listener` with `odin_activity_add_listener` in
 * vendor:android/java.
 */
public class OdinActivity extends android.app.NativeActivity {
	public interface Listener {
		void onActivityResult(int requestCode, int resultCode, Intent data);
		void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults);
		void onNewIntent(Intent intent);
	}

	private final CopyOnWriteArrayList<Listener> listeners = new CopyOnWriteArrayList<>();

	public void addListener(Listener listener) {
		listeners.add(listener);
	}

	public void removeListener(Listener listener) {
		listeners.remove(listener);
	}

	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		for (Listener listener : listeners) {
			listener.onActivityResult(requestCode, resultCode, data);
		}
	}

	@Override
	public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults);
		for (Listener listener : listeners) {
			listener.onRequestPermissionsResult(requestCode, permissions, grantResults);
		}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		// So `getIntent` returns the newest intent, as most apps expect.
		setIntent(intent);
		for (Listener listener : listeners) {
			listener.onNewIntent(intent);
		}
	}
}
