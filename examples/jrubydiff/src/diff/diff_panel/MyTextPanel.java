/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package diff.diff_panel;

import java.awt.Color;
import java.awt.Container;
import java.awt.Dimension;
import javax.swing.JTextPane;
import javax.swing.text.BadLocationException;
import javax.swing.text.Style;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyleContext;
import javax.swing.text.StyledDocument;

/**
 *
 * @author Administrator
 */
public class MyTextPanel  extends JTextPane{
    
    public static final String SAME_STYLE = "same", DIFF_STYLE = "diff", ADD_STYLE = "add";

    private StyledDocument doc;
    private Style sameStyle, diffStyle, addStyle;

    public MyTextPanel()
    {
        super();
        initStyles();
        setSize(Integer.MAX_VALUE, Integer.MAX_VALUE);
    }

    @Override
    public boolean getScrollableTracksViewportWidth()
    {
        return false;
    }

    @Override
    public void setBounds(int x, int y, int width, int height) {

        Container parent = getParent();
        if (parent != null) {
            Dimension parentSize = parent.getSize();
            Dimension size = getPreferredSize();
            width = (size.width < parentSize.width) ? parentSize.width : size.width;
            height = (size.height < parentSize.height) ? parentSize.height : size.height;
        }
        super.setBounds(x, y, width, height);
    }

    public void clear() {
        setText("");
    }

    public void insertString(String content, String strStyle) throws BadLocationException {
        Style style = sameStyle;
        if (strStyle.equals(DIFF_STYLE))
                style = diffStyle;
        else if (strStyle.equals(ADD_STYLE))
                style = addStyle;

        doc.insertString(doc.getLength(), content, style);
    }

    private void initStyles() {
        doc = getStyledDocument();

        sameStyle = StyleContext.getDefaultStyleContext().getStyle(StyleContext.DEFAULT_STYLE);
        sameStyle.addAttribute(StyleConstants.FontFamily, "Monospaced");
        doc.addStyle(SAME_STYLE, sameStyle);
        addStyle = doc.addStyle(DIFF_STYLE, sameStyle);
        addStyle.addAttribute(StyleConstants.Background, new Color(186, 100, 186));
        diffStyle = doc.addStyle(DIFF_STYLE, sameStyle);
        diffStyle.addAttribute(StyleConstants.Background, new Color(186, 186, 186));
    }
}
