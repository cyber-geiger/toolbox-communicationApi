package eu.cybergeiger.communication;

import java.io.IOException;

public class CommunicationException extends IOException {

    public CommunicationException(String txt, Throwable e) {
        super(txt, e);
    }

    public CommunicationException(String txt) {
        this(txt, null);
    }
}
