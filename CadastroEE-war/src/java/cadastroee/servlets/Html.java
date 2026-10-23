package cadastroee.servlets;

/**
 * Utilitário para escapar texto antes de escrevê-lo em HTML
 * (evita que um nome de produto com "&lt;" quebre a página ou injete script).
 */
public final class Html {

    private Html() {
    }

    public static String esc(Object valor) {
        if (valor == null) {
            return "";
        }
        String s = valor.toString();
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '&': sb.append("&amp;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }
}
