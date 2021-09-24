abstract class TcMatcher
{
    Matcher matcher(String s);

    bool matches();

    String group(int num);

    String pattern();

}
