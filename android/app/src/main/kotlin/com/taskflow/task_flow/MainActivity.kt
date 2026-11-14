package com.taskflow.task_flow

import android.accounts.AccountManager
import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.taskflow.task_flow/device_accounts"
    private val REQUEST_CODE_PICK_ACCOUNT = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRealGoogleAccount" -> {
                    try {
                        pendingResult = result
                        val intent = AccountManager.newChooseAccountIntent(
                            null,
                            null,
                            arrayOf("com.google"),
                            false,
                            null,
                            null,
                            null,
                            null
                        )
                        startActivityForResult(intent, REQUEST_CODE_PICK_ACCOUNT)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICKER_ERROR", e.localizedMessage, null)
                    }
                }
                "getDeviceGoogleAccounts" -> {
                    try {
                        val accountManager = AccountManager.get(applicationContext)
                        val accounts = accountManager.getAccountsByType("com.google")
                        val emails = accounts.map { it.name }
                        result.success(emails)
                    } catch (e: Exception) {
                        result.success(emptyList<String>())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_ACCOUNT) {
            val res = pendingResult
            pendingResult = null
            if (res != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    val accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                    if (accountName != null && accountName.isNotEmpty()) {
                        res.success(accountName)
                    } else {
                        res.success(null)
                    }
                } else {
                    res.success(null)
                }
            }
        }
    }
}
