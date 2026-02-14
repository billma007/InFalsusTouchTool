package com.billma007.infalsustouch

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.billma007.infalsustouch.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Disable autofill hints programmatically if XML didn't catch it
        binding.ipInput.importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO

        binding.connectButton.setOnClickListener {
            val ip = binding.ipInput.text.toString()
            if (ip.isNotBlank()) {
                if (NetworkManager.connect(ip)) {
                    val intent = Intent(this, FullMappingActivity::class.java)
                    startActivity(intent)
                } else {
                    binding.errorText.text = NetworkManager.errorMsg
                }
            } else {
                Toast.makeText(this, "Please enter IP", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
