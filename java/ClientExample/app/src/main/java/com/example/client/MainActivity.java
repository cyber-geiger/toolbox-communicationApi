package com.example.client;

import android.os.Bundle;

import androidx.appcompat.app.AppCompatActivity;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.communication.GeigerService;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        GeigerService.startPlugin(getApplicationContext());
    }
}