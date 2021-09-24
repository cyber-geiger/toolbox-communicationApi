
import 'java.dart';
/// Exception class to denote a malformed URL.
class MalformedUrlException extends java_io_IOException
{
    MalformedUrlException(String msg)
    {
        super(msg);
    }

    MalformedUrlException(String msg, Exception e)
    {
        super(msg, e);
    }

}
