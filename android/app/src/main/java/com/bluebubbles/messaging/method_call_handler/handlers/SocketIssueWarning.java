package com.bluebubbles.messaging.method_call_handler.handlers;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.bluebubbles.messaging.MainActivity;
import com.bluebubbles.messaging.R;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SocketIssueWarning implements Handler {

    public static String TAG = "create-socket-issue-warning";
    public final static String TYPE = "SocketErrorOpen";

    private Context context;

    private MethodCall call;
    private MethodChannel.Result result;

    public SocketIssueWarning(Context context, MethodCall call, MethodChannel.Result result) {
        this.context = context;
        this.call = call;
        this.result = result;
    }

    @Override
    public void Handle() {
        PendingIntent openIntent = PendingIntent.getActivity(
                context,
                4000,
                new Intent(context, MainActivity.class).setType(TYPE)
                        .putExtra("id", -2)
                        .putExtra("chatGuid", "-2"),
                PendingIntent.FLAG_MUTABLE | Intent.FILL_IN_ACTION);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, (String) call.argument("CHANNEL_ID"))
                .setSmallIcon(R.mipmap.ic_stat_icon)
                .setContentTitle("Could not connect")
                .setContentText("Your server may be offline")
                .setColor(4888294)
                .setContentIntent(openIntent)
                .setOngoing(true);

        NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);
        notificationManagerCompat.notify(1000, builder.build());
        result.success("");
    }
}
